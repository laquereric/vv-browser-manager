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
