/**
 * ================================================================================
 *
 * @project:    @monorepo/data-generator
 * @file:       ~/layers/data-generator/utils/uuidv7.ts
 * @version:    V1.0.1
 * @createDate: 2025 Dec 13
 * @createTime: 23:12
 * @author:     Steve R Lewis
 *
 * ================================================================================
 *
 * @description:
 * TODO: Create description here
 *
 * ================================================================================
 *
 * @notes: Revision History
 
 V1.0.1, 20251216-2137
 Fixed null reference in user loop.
*
 * V1.0.0, 20251213-23:12
 * Initial creation and release of uuidv7.ts
 *
 * ================================================================================
 */

/**
 * RFC 9562 – UUID Version 7 (time-ordered)
 *
 * - 48-bit Unix epoch timestamp in milliseconds
 * - Monotonic ordering by timestamp
 * - Cryptographically strong randomness for remaining bits
 * - Intended for development and test data generation
 */
export function uuidv7(date: Date = new Date()): string {
  const timestamp = BigInt(date.getTime())


// 48-bit timestamp (milliseconds since Unix epoch)
  const time48 = timestamp & 0x0000ffffffffffffn


// Random components
  const randA = crypto.getRandomValues(new Uint8Array(2))
  const randB = crypto.getRandomValues(new Uint8Array(8))


  const part1 = (time48 >> 16n).toString(16).padStart(8, '0')
  const part2 = (time48 & 0xffffn).toString(16).padStart(4, '0')


// Version 7 (0b0111)
  const part3 = (
    0x7000 |
    (randA[0] & 0x0fff)
  ).toString(16).padStart(4, '0')


// RFC 4122 variant (10xx)
  const part4 = (
    0x8000 |
    ((randA[1] & 0x3f) << 8)
  ).toString(16).padStart(4, '0')


  const part5 = Array.from(randB)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')


  return `${part1}-${part2}-${part3}-${part4}-${part5}`
}


/**
 * Generate a sorted list of UUID v7 values evenly distributed
 * between the provided start and end dates.
 */
export function generateUuidRange(
  count: number,
  start: Date,
  end: Date
): string[] {
  if (count <= 0) return []


  const startMs = start.getTime()
  const endMs = end.getTime()


  if (endMs <= startMs) return []


  const step = Math.floor((endMs - startMs) / count)


  const result: { ts: number; id: string }[] = []


  for (let i = 0; i < count; i++) {
    const ts = startMs + i * step
    result.push({
      ts,
      id: uuidv7(new Date(ts))
    })
  }


  return result
    .sort((a, b) => a.ts - b.ts)
    .map(r => r.id)
}


