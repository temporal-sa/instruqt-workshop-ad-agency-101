# frozen_string_literal: true

require 'temporalio/workflow'

class CampaignApprovalWorkflow < Temporalio::Workflow::Definition
  def initialize
    @approved_by = nil
  end

  # The Signal name defaults to the method name: approve.
  workflow_signal
  def approve(approver)
    # TODO: Part B — record who approved so the wait below can see it.
  end

  def execute(campaign, approval_deadline_seconds)
    Temporalio::Workflow.logger.info(
      "Campaign #{campaign} awaiting client approval (deadline #{approval_deadline_seconds}s)"
    )

    # TODO: Part C — wait durably for @approved_by to be set, up to the
    # deadline. Replace the placeholder below with:
    #
    # received = begin
    #   Temporalio::Workflow.timeout(approval_deadline_seconds) do
    #     Temporalio::Workflow.wait_condition { @approved_by }
    #   end
    #   true
    # rescue Timeout::Error
    #   false
    # end
    received = false
    return expired(campaign) unless received

    {
      'campaign' => campaign,
      'status' => 'APPROVED',
      'approved_by' => @approved_by,
      'next_step' => 'cleared for launch'
    }
  end

  private

  def expired(campaign)
    {
      'campaign' => campaign,
      'status' => 'EXPIRED',
      'approved_by' => nil,
      'next_step' => 'escalate to the account exec (by fax, probably)'
    }
  end
end
