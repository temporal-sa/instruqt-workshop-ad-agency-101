package tagline

import "go.temporal.io/sdk/workflow"

// TaglineWorkflow is a Workflow Definition: an exported function whose first
// parameter is workflow.Context. Its Workflow Type is the function name.
func TaglineWorkflow(ctx workflow.Context, brand string) (string, error) {
	workflow.GetLogger(ctx).Info("Generating tagline", "brand", brand)
	// TODO: Part B — return the tagline: the brand name, a colon and a space,
	// then "Taste the Meow!"  e.g.  "CatNip Cola: Taste the Meow!"
	return "TODO", nil
}
