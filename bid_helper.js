const { ethers } = require("ethers");

function createCommitment(amountInWei, salt) {
    return ethers.solidityPackedKeccak256(
        ["uint256", "string"],
        [amountInWei, salt]
    );
}

const salt = "secret_random_string";
const amount = ethers.parseEther("1.5");
const commitment = createCommitment(amount, salt);

console.log(`Amount: 1.5 ETH`);
console.log(`Salt: ${salt}`);
console.log(`Commitment Hash: ${commitment}`);
