package cloud

import "go.temporal.io/sdk/workflow"

// TaglineWorkflow is unchanged from exercise 2.
func TaglineWorkflow(ctx workflow.Context, brand string) (string, error) {
	workflow.GetLogger(ctx).Info("Generating tagline", "brand", brand)
	return brand + ": Taste the Meow!", nil
}
