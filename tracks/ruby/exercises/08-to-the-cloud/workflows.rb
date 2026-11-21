# frozen_string_literal: true

require 'temporalio/workflow'

class TaglineWorkflow < Temporalio::Workflow::Definition
  def execute(brand)
    Temporalio::Workflow.logger.info("Generating tagline for #{brand}")
    "#{brand}: Taste the Meow!"
  end
end
