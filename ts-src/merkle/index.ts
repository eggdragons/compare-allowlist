import { importJson, outputJson } from "../utils/output";
import { createMerkleTree, createMerkleDatas, verify } from "./func";

// setting
const name = process.argv[2] ? process.argv[2] : 128;
const outputDirectory = "./data/merkle/";

// import allowlist
const allowlists: Allowlist[] = importJson(
  "./data/allowlist/allowlists" + name + ".json"
);

// createMerkleTree
const { root, proofs } = createMerkleTree(allowlists);

// create merkleDatas
const merkleDatas = createMerkleDatas(allowlists, proofs);

// verify
verify(merkleDatas, root);

// output json
// outputJson(proofs, "./data/merkle/proofs" + name + ".json");
outputJson(root, outputDirectory, "root" + name + ".json");

outputJson(
  createMerkleDatas(allowlists, proofs),
  outputDirectory,
  "merkleDatas" + name + ".json"
);
