import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { ItemCanceled } from "../generated/schema"
import { ItemCanceled as ItemCanceledEvent } from "../generated/NFTMarket/NFTMarket"
import { handleItemCanceled } from "../src/nft-market"
import { createItemCanceledEvent } from "./nft-market-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let nft = Address.fromString("0x0000000000000000000000000000000000000001")
    let tokenId = BigInt.fromI32(234)
    let status = 123
    let newItemCanceledEvent = createItemCanceledEvent(nft, tokenId, status)
    handleItemCanceled(newItemCanceledEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("ItemCanceled created and stored", () => {
    assert.entityCount("ItemCanceled", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "ItemCanceled",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "nft",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "ItemCanceled",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "tokenId",
      "234"
    )
    assert.fieldEquals(
      "ItemCanceled",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "status",
      "123"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
