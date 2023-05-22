import { solidityPackedKeccak256 } from "ethers";
import { MerkleTree } from "merkletreejs";
import { keccak256 } from "ethers";

export const createLeaves = (allowlist: Allowlist) => {
  return solidityPackedKeccak256(
    ["address", "uint256"],
    [allowlist.user, allowlist.allowedAmount]
  );
};

export const createMerkleTree = (allowlists: Allowlist[]) => {
  const leaves = allowlists.map((x) => createLeaves(x));
  const tree = new MerkleTree(leaves, keccak256, { sort: true });
  const proofs = leaves.map((allowlist) => tree.getHexProof(allowlist));
  const root = tree.getHexRoot();

  return { root, proofs };
};

export const createMerkleDatas = (
  allowlists: Allowlist[],
  proofs: string[][]
) => {
  const merkleDatas: MerkleData[] = allowlists.map((allowlist, i) => {
    return {
      ...allowlist,
      proofs: proofs[i],
    };
  });

  return merkleDatas;
};

export const verify = (merkleDatas: MerkleData[], root: string) => {
  for (let i = 0; i < merkleDatas.length; ++i) {
    const check = MerkleTree.verify(
      merkleDatas[i].proofs,
      createLeaves({
        user: merkleDatas[i].user,
        allowedAmount: merkleDatas[i].allowedAmount,
      }),
      root,
      keccak256,
      { sort: true }
    );
    if (!check) {
      throw new Error(`Verification failed for allowlist at index ${i}`);
    }
  }
};
