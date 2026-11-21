# frozen_string_literal: true

require 'temporalio/workflow'

# A Workflow is a class that subclasses Temporalio::Workflow::Definition.
# Its Workflow type defaults to the class name: TaglineWorkflow.
class TaglineWorkflow < Temporalio::Workflow::Definition
  def execute(brand)
    Temporalio::Workflow.logger.info("Generating tagline for #{brand}")
    # TODO: Part B — return the tagline: the brand name, a colon and a space,
    # then "Taste the Meow!"  e.g.  "CatNip Cola: Taste the Meow!"
    'TODO'
  end
end
