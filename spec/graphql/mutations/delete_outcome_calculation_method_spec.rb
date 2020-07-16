#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::DeleteOutcomeCalculationMethod do
  before :once do
    @account = Account.default
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: 'active').user
    @student = @course.enroll_student(User.create!, enrollment_state: 'active').user
  end

  let(:original_record) { outcome_calculation_method_model(@course) }

  def execute_with_input(delete_input, user_executing: @teacher)
    mutation_command = <<~GQL
      mutation {
        deleteOutcomeCalculationMethod(input: {
          #{delete_input}
        }) {
          outcomeCalculationMethodId
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = {current_user: user_executing, deleted_models: {}, request: ActionDispatch::TestRequest.create, session: {}}
    CanvasSchema.execute(mutation_command, context: context)
  end

  it "deletes an outcome calculation method" do
    query = <<~QUERY
      id: #{original_record.id}
    QUERY
    result = execute_with_input(query)
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'deleteOutcomeCalculationMethod', 'errors')).to be_nil
    expect(result.dig('data', 'deleteOutcomeCalculationMethod', 'outcomeCalculationMethodId')).to eq original_record.id.to_s
  end

  context 'errors' do
    def expect_error(result, message)
      errors = result.dig('errors') || result.dig('data', 'deleteOutcomeCalculationMethod', 'errors')
      expect(errors).not_to be_nil
      expect(errors[0]['message']).to match(/#{message}/)
    end

    it "requires manage_outcomes permission" do
      query = <<~QUERY
        id: #{original_record.id}
      QUERY
      result = execute_with_input(query, user_executing: @student)
      expect_error(result, 'insufficient permission')
    end

    it "invalid id" do
      query = <<~QUERY
        id: -100
      QUERY
      result = execute_with_input(query)
      expect_error(result, 'Unable to find OutcomeCalculationMethod')
    end
  end
end