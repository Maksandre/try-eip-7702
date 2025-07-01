import { beforeAll, afterAll } from 'vitest'

// Global test setup
beforeAll(() => {
  // Set up any global test configuration
  console.log('Setting up test environment...')
})

afterAll(() => {
  // Clean up after all tests
  console.log('Cleaning up test environment...')
})

// Global test utilities
export const TEST_TIMEOUT = 30000 // 30 seconds

// Helper function to wait for a specific time
export const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

// Helper function to generate random addresses
export const generateRandomAddress = () => {
  return `0x${Array.from({ length: 40 }, () => 
    Math.floor(Math.random() * 16).toString(16)
  ).join('')}`
} 