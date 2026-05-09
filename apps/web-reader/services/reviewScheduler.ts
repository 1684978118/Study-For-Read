import type { WebReviewStatus } from '../types/localData'

export interface ReviewScheduleInput {
  known: boolean
  reviewCount: number
  reviewedAt: string
}

export interface ReviewScheduleResult {
  reviewStatus: WebReviewStatus
  reviewCount: number
  reviewedAt: string
  lastReviewedAt: string
  nextReviewAt: string
}

export function scheduleReview(input: ReviewScheduleInput): ReviewScheduleResult {
  const nextReviewCount = input.reviewCount + 1
  const reviewedAt = new Date(input.reviewedAt)
  const intervalDays = input.known ? knownIntervalDays(input.reviewCount) : 1
  const nextReviewAt = new Date(reviewedAt)
  nextReviewAt.setUTCDate(nextReviewAt.getUTCDate() + intervalDays)

  return {
    reviewStatus: input.known ? statusForKnownReview(nextReviewCount) : 'learning',
    reviewCount: nextReviewCount,
    reviewedAt: input.reviewedAt,
    lastReviewedAt: input.reviewedAt,
    nextReviewAt: nextReviewAt.toISOString(),
  }
}

function knownIntervalDays(previousReviewCount: number): number {
  if (previousReviewCount <= 0) {
    return 3
  }
  if (previousReviewCount === 1) {
    return 7
  }
  if (previousReviewCount === 2) {
    return 15
  }
  return 30
}

function statusForKnownReview(reviewCount: number): WebReviewStatus {
  return reviewCount >= 4 ? 'mastered' : 'reviewing'
}
