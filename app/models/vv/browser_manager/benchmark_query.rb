module Vv
  module BrowserManager
    class BenchmarkQuery < ActiveRecord::Base
      self.table_name = "vv_benchmark_queries"

      has_many :benchmark_results, dependent: :destroy

      validates :name, presence: true, uniqueness: true
      validates :category, presence: true
      validates :system_prompt, :user_prompt, presence: true
      validates :expected_format, inclusion: { in: %w[json text] }

      scope :by_category, ->(category) { where(category: category) }

      SEED_QUERIES = [
        {
          name: "form_validation_simple",
          category: "form_validation",
          system_prompt: "You are a form validation assistant. Analyze the form data and determine if it is valid for submission. Respond with JSON: {\"answer\": \"yes\" or \"no\", \"explanation\": \"why\"}",
          user_prompt: "Form: Add Beneficiary\nFields:\n- beneficiary_name: \"John Smith\"\n- relationship: \"Spouse\"\n- ssn: \"123456789\"\n- date_of_birth: \"1985-03-15\"\n- allocation_percentage: \"100\"\n\nIs this form valid for submission?",
          expected_format: "json",
          expected_keys: ["answer", "explanation"],
        },
        {
          name: "form_validation_self_beneficiary",
          category: "form_validation",
          system_prompt: "You are a form validation assistant. Analyze the form data and determine if it is valid for submission. Respond with JSON: {\"answer\": \"yes\" or \"no\", \"explanation\": \"why\"}",
          user_prompt: "Form: Add Beneficiary\nFields:\n- beneficiary_name: \"Eric Laquer\"\n- relationship: \"Self\"\n- ssn: \"987654321\"\n- date_of_birth: \"1990-01-01\"\n- allocation_percentage: \"100\"\n\nThe account holder is Eric Laquer. Is this form valid for submission?",
          expected_format: "json",
          expected_keys: ["answer", "explanation"],
        },
        {
          name: "form_validation_missing_fields",
          category: "form_validation",
          system_prompt: "You are a form validation assistant. Analyze the form data and determine if it is valid for submission. Respond with JSON: {\"answer\": \"yes\" or \"no\", \"explanation\": \"why\"}",
          user_prompt: "Form: Add Beneficiary\nFields:\n- beneficiary_name: \"\"\n- relationship: \"\"\n- ssn: \"\"\n- date_of_birth: \"\"\n- allocation_percentage: \"\"\n\nIs this form valid for submission?",
          expected_format: "json",
          expected_keys: ["answer", "explanation"],
        },
        {
          name: "field_help_ssn",
          category: "field_help",
          system_prompt: "You are a form field help assistant. The user is asking for help understanding a form field. Respond with JSON: {\"help\": \"clear explanation of the field\"}",
          user_prompt: "Form: Add Beneficiary\nField: ssn (Social Security Number)\nThe user typed '?' in this field. Explain what this field is for and what format is expected.",
          expected_format: "json",
          expected_keys: ["help"],
        },
        {
          name: "field_help_beneficiary_name",
          category: "field_help",
          system_prompt: "You are a form field help assistant. The user is asking for help understanding a form field. Respond with JSON: {\"help\": \"clear explanation of the field\"}",
          user_prompt: "Form: Add Beneficiary\nField: beneficiary_name (Beneficiary Name)\nThe user typed '?' in this field. Explain what this field is for and who should be listed.",
          expected_format: "json",
          expected_keys: ["help"],
        },
        {
          name: "error_resolution_ssn_format",
          category: "error_resolution",
          system_prompt: "You are a form error resolution assistant. The user submitted a form and got validation errors. Translate the errors into plain-language fix suggestions. Respond with JSON: {\"suggestions\": {\"field_name\": \"suggestion\"}, \"summary\": \"overall guidance\"}",
          user_prompt: "Form: Add Beneficiary\nValidation errors:\n- ssn: \"Must be 9 digits\"\n\nCurrent field values:\n- ssn: \"12345\"\n\nProvide fix suggestions.",
          expected_format: "json",
          expected_keys: ["suggestions", "summary"],
        },
        {
          name: "error_resolution_multiple",
          category: "error_resolution",
          system_prompt: "You are a form error resolution assistant. The user submitted a form and got validation errors. Translate the errors into plain-language fix suggestions. Respond with JSON: {\"suggestions\": {\"field_name\": \"suggestion\"}, \"summary\": \"overall guidance\"}",
          user_prompt: "Form: Add Beneficiary\nValidation errors:\n- beneficiary_name: \"Can't be blank\"\n- ssn: \"Must be 9 digits\"\n- allocation_percentage: \"Must be between 1 and 100\"\n\nCurrent field values:\n- beneficiary_name: \"\"\n- ssn: \"abc\"\n- allocation_percentage: \"150\"\n\nProvide fix suggestions.",
          expected_format: "json",
          expected_keys: ["suggestions", "summary"],
        },
        {
          name: "memory_reflection",
          category: "memory_reflection",
          system_prompt: "You are a memory reflection assistant. Given facts about user interactions with a form, derive opinions and observations. Respond with JSON: {\"opinions\": [{\"content\": \"belief\", \"confidence\": 0.0-1.0, \"category\": \"field_difficulty|user_pattern|form_flow\"}], \"observations\": [{\"pattern\": \"description\", \"category\": \"help_pattern|error_pattern|pause_pattern|behavior_pattern\"}]}",
          user_prompt: "Session facts:\n- beneficiary_name: is_field = true\n- ssn: is_field = true\n- beneficiary_name: has_value = \"John Smith\"\n- ssn: was_focused at 14:32:01 (3 seconds)\n- ssn: was_focused at 14:32:04 (held 8 seconds before typing)\n- ssn: field_help_requested at 14:32:12\n- ssn: has_value = \"123456789\"\n- form was submitted at 14:32:30\n- ssn: had_error = \"Must be 9 digits\" (first attempt had \"12345\")\n\nDerive opinions and observations from these facts.",
          expected_format: "json",
          expected_keys: ["opinions", "observations"],
        },
        # --- Context analysis ---
        {
          name: "context_analysis_simple",
          category: "context_analysis",
          system_prompt: "You are a concise context analyzer. Given page content and app context, return JSON: {\"summary\":\"one-sentence description of what the user is looking at\",\"systemPromptPatch\":\"brief context to help an assistant understand the current page\"}. Return ONLY valid JSON, no markdown.",
          user_prompt: "Page title: Beneficiary Designation\nURL: http://localhost:3003/\nPage text (truncated): Example App Beneficiary First Name Last Name E Pluribus Unum Send\n\nApp context: {\"description\":\"Beneficiary designation form\",\"currentUser\":\"John Jones\",\"formTitle\":\"Beneficiary\"}",
          expected_format: "json",
          expected_keys: ["summary", "systemPromptPatch"],
        },
        {
          name: "context_analysis_filled_form",
          category: "context_analysis",
          system_prompt: "You are a concise context analyzer. Given page content and app context, return JSON: {\"summary\":\"one-sentence description of what the user is looking at\",\"systemPromptPatch\":\"brief context to help an assistant understand the current page\"}. Return ONLY valid JSON, no markdown.",
          user_prompt: "Page title: Beneficiary Designation\nURL: http://localhost:3003/\nPage text: Example App Beneficiary First Name Jane Last Name Doe E Pluribus Unum Out of many Send\n\nApp context: {\"description\":\"Beneficiary designation form\",\"currentUser\":\"John Jones\",\"formTitle\":\"Beneficiary\",\"formFields\":{\"first_name\":{\"value\":\"Jane\",\"label\":\"First Name\"},\"last_name\":{\"value\":\"Doe\",\"label\":\"Last Name\"},\"e_pluribus_unum\":{\"value\":\"Out of many\",\"label\":\"E Pluribus Unum\"}}}",
          expected_format: "json",
          expected_keys: ["summary", "systemPromptPatch"],
        },
        # --- Additional form validation ---
        {
          name: "form_validation_partial_fields",
          category: "form_validation",
          system_prompt: "You are a form validation assistant. Analyze the form data and determine if it is valid for submission. Respond with JSON: {\"answer\": \"yes\" or \"no\", \"explanation\": \"why\"}",
          user_prompt: "Form: Add Beneficiary\nFields:\n- beneficiary_name: \"Jane Doe\"\n- relationship: \"Child\"\n- ssn: \"\"\n- date_of_birth: \"2010-06-15\"\n- allocation_percentage: \"50\"\n\nIs this form valid for submission? Note: SSN is required.",
          expected_format: "json",
          expected_keys: ["answer", "explanation"],
        },
        {
          name: "form_validation_invalid_percentage",
          category: "form_validation",
          system_prompt: "You are a form validation assistant. Analyze the form data and determine if it is valid for submission. Respond with JSON: {\"answer\": \"yes\" or \"no\", \"explanation\": \"why\"}",
          user_prompt: "Form: Add Beneficiary\nFields:\n- beneficiary_name: \"Alice Smith\"\n- relationship: \"Spouse\"\n- ssn: \"111223333\"\n- date_of_birth: \"1988-12-01\"\n- allocation_percentage: \"150\"\n\nIs this form valid for submission? Note: allocation_percentage must be between 1 and 100.",
          expected_format: "json",
          expected_keys: ["answer", "explanation"],
        },
        # --- Additional field help ---
        {
          name: "field_help_relationship",
          category: "field_help",
          system_prompt: "You are a form field help assistant. The user is asking for help understanding a form field. Respond with JSON: {\"help\": \"clear explanation of the field\"}",
          user_prompt: "Form: Add Beneficiary\nField: relationship (Relationship to Account Holder)\nThe user typed '?' in this field. Explain what this field is for and what values are appropriate.",
          expected_format: "json",
          expected_keys: ["help"],
        },
        {
          name: "field_help_allocation",
          category: "field_help",
          system_prompt: "You are a form field help assistant. The user is asking for help understanding a form field. Respond with JSON: {\"help\": \"clear explanation of the field\"}",
          user_prompt: "Form: Add Beneficiary\nField: allocation_percentage (Allocation Percentage)\nThe user typed '?' in this field. Explain what this field means in the context of beneficiary designations, including what happens when there are multiple beneficiaries.",
          expected_format: "json",
          expected_keys: ["help"],
        },
        # --- Additional error resolution ---
        {
          name: "error_resolution_date_format",
          category: "error_resolution",
          system_prompt: "You are a form error resolution assistant. The user submitted a form and got validation errors. Translate the errors into plain-language fix suggestions. Respond with JSON: {\"suggestions\": {\"field_name\": \"suggestion\"}, \"summary\": \"overall guidance\"}",
          user_prompt: "Form: Add Beneficiary\nValidation errors:\n- date_of_birth: \"Invalid date format, expected YYYY-MM-DD\"\n- date_of_birth: \"Must be a date in the past\"\n\nCurrent field values:\n- date_of_birth: \"March 15, 1985\"\n\nProvide fix suggestions.",
          expected_format: "json",
          expected_keys: ["suggestions", "summary"],
        },
        {
          name: "error_resolution_self_designation",
          category: "error_resolution",
          system_prompt: "You are a form error resolution assistant. The user submitted a form and got validation errors. Translate the errors into plain-language fix suggestions. Respond with JSON: {\"suggestions\": {\"field_name\": \"suggestion\"}, \"summary\": \"overall guidance\"}",
          user_prompt: "Form: Add Beneficiary\nAccount holder: John Jones\nValidation errors:\n- beneficiary_name: \"Cannot designate yourself as beneficiary\"\n- relationship: \"Cannot be 'Self' for beneficiary designation\"\n\nCurrent field values:\n- beneficiary_name: \"John Jones\"\n- relationship: \"Self\"\n\nProvide fix suggestions.",
          expected_format: "json",
          expected_keys: ["suggestions", "summary"],
        },
        # --- Summarization ---
        {
          name: "session_summary",
          category: "summarization",
          system_prompt: "You are a session summarizer. Given a list of events from a form-filling session, produce a concise summary. Respond with JSON: {\"summary\": \"2-3 sentence overview\", \"duration_estimate\": \"estimated time spent\", \"issues\": [\"list of problems encountered\"]}",
          user_prompt: "Session events:\n1. FormOpened: Beneficiary form at 14:30:00\n2. FormPolled: 0/3 fields filled at 14:30:05\n3. FormStateChanged: first_name = \"Jane\" at 14:30:12\n4. FieldHelpRequested: last_name at 14:30:18\n5. FormStateChanged: last_name = \"Doe\" at 14:30:25\n6. FormPolled: 2/3 fields filled at 14:30:30\n7. FormStateChanged: e_pluribus_unum = \"unity\" at 14:30:40\n8. FormSubmitted at 14:30:42\n9. AssistantResponded: validation passed at 14:30:45\n\nSummarize this session.",
          expected_format: "json",
          expected_keys: ["summary", "duration_estimate", "issues"],
        },
        # --- Chat / general knowledge ---
        {
          name: "chat_form_question",
          category: "chat",
          system_prompt: "You are a helpful assistant embedded in a beneficiary designation form. Answer the user's question concisely. Respond with JSON: {\"response\": \"your answer\"}",
          user_prompt: "What is a beneficiary and why do I need to designate one?",
          expected_format: "json",
          expected_keys: ["response"],
        },
        {
          name: "chat_legal_question",
          category: "chat",
          system_prompt: "You are a helpful assistant embedded in a beneficiary designation form. Answer the user's question concisely. Respond with JSON: {\"response\": \"your answer\"}",
          user_prompt: "Can I change my beneficiary later, or is this permanent?",
          expected_format: "json",
          expected_keys: ["response"],
        },
        {
          name: "chat_e_pluribus_unum",
          category: "chat",
          system_prompt: "You are a helpful assistant embedded in a form. The form has a field labeled 'E Pluribus Unum'. Answer the user's question concisely. Respond with JSON: {\"response\": \"your answer\"}",
          user_prompt: "What does E Pluribus Unum mean and what should I put in this field?",
          expected_format: "json",
          expected_keys: ["response"],
        },
      ].freeze

      def self.seed!
        SEED_QUERIES.each do |attrs|
          query = find_or_initialize_by(name: attrs[:name])
          query.assign_attributes(attrs)
          query.save!
        end
      end
    end
  end
end
