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

  describe("swaps", function () {
    it("swap60", async function () {
      await fuzzingTest2.univ3_fuzzing_test(60, { value: ethers.utils.parseUnits("100", "ether") });
    });

    it("swap120", async function () {
      await fuzzingTest2.univ3_fuzzing_test(120, { value: ethers.utils.parseUnits("100", "ether") });
    });

    it("swap180", async function () {
      await fuzzingTest2.univ3_fuzzing_test(180, { value: ethers.utils.parseUnits("100", "ether") });
    });

    it("swap240", async function () {
      await fuzzingTest2.univ3_fuzzing_test(240, { value: ethers.utils.parseUnits("100", "ether") });
    });

    it("swap300", async function () {
      await fuzzingTest2.univ3_fuzzing_test(300, { value: ethers.utils.parseUnits("100", "ether") });
    });

});
});

