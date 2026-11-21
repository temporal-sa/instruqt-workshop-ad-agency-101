# frozen_string_literal: true

require 'temporalio/workflow'

# A Workflow is a class that subclasses Temporalio::Workflow::Definition.
# Its Workflow type defaults to the class name: TaglineWorkflow.
class TaglineWorkflow < Temporalio::Workflow::Definition
  def execute(brand)
    Temporalio::Workflow.logger.info("Generating tagline for #{brand}")
    "#{brand}: Taste the Meow!"
  end
end
