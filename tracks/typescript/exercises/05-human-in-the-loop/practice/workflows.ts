import { condition, defineSignal, log, setHandler } from '@temporalio/workflow';

export const approve = defineSignal<[approver: string]>('approve');

export interface ApprovalReport {
  campaign: string;
  status: 'APPROVED' | 'EXPIRED';
  approved_by: string | null;
  next_step: string;
}

export async function campaignApprovalWorkflow(
  campaign: string,
  approvalDeadlineSeconds: number,
): Promise<ApprovalReport> {
  let approvedBy: string | undefined;

  setHandler(approve, (approver: string) => {
    // TODO: Part B — record who approved so the condition below can see it.
    void approver;
  });

  log.info('Campaign awaiting client approval', {
    campaign,
    approvalDeadlineSeconds,
  });

  // TODO: Part C — wait durably for approvedBy to be set, up to the deadline:
  // const received = await condition(
  //   () => approvedBy !== undefined,
  //   approvalDeadlineSeconds * 1_000,
  // );
  const received = false;

  if (!received) {
    return {
      campaign,
      status: 'EXPIRED',
      approved_by: null,
      next_step: 'escalate to the account exec (by fax, probably)',
    };
  }
  return {
    campaign,
    status: 'APPROVED',
    approved_by: approvedBy ?? null,
    next_step: 'cleared for launch',
  };
}

void condition; // Keeps the teaching import live until the TODO is completed.
