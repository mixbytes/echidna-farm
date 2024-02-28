//const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniV3 swap test", function () {

  let FuzzingTest2;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    const provider = new ethers.providers.JsonRpcProvider("https://free-eth-node.com/api/eth");

    FuzzingTest2 = await ethers.getContractFactory("FuzzingTest2");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    fuzzingTest2 = await FuzzingTest2.deploy();

  });

  describe("swap", function () {
    it("Should swap", async function () {
      await fuzzingTest2.univ3_fuzzing_test({ value: ethers.utils.parseUnits("100", "ether") });
      //await fuzzingTest2.univ3_swap({ value: ethers.utils.parseUnits("1", "ether") });
    });

  });

});
