# frozen_string_literal: true

require 'temporalio/workflow'

class CampaignApprovalWorkflow < Temporalio::Workflow::Definition
  def initialize
    @approved_by = nil
  end

  # The Signal name defaults to the method name: approve.
  workflow_signal
  def approve(approver)
    @approved_by = approver
  end

  def execute(campaign, approval_deadline_seconds)
    Temporalio::Workflow.logger.info(
      "Campaign #{campaign} awaiting client approval (deadline #{approval_deadline_seconds}s)"
    )

    # Workflow.timeout is backed by a durable Temporal timer. wait_condition
    # blocks until the block is truthy; neither holds an OS thread.
    received = begin
      Temporalio::Workflow.timeout(approval_deadline_seconds) do
        Temporalio::Workflow.wait_condition { @approved_by }
      end
      true
    rescue Timeout::Error
      false
    end
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
