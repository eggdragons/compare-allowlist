import { importJson, outputJson } from "../utils/output";
import { generatePrivateKeyFromHash } from "../utils/random";
import {
  createSignature,
  createSignDatas,
  createTicketDatas,
  verify,
} from "./func";

// setting
const name = process.argv[2] ? process.argv[2] : 128;
const outputDirectory = "./data/ecdsa/";

// singer privateKey
const currentDateTime = new Date().toString();
const privateKey = generatePrivateKeyFromHash(currentDateTime);

// import allowlist
const allowlists: Allowlist[] = importJson(
  "./data/allowlist/allowlists" + name + ".json"
);

// createTicketDatas
const { ticketDatas, bits } = createTicketDatas(allowlists);

// create signatures
const { signerAddress, signatures } = createSignature(ticketDatas, privateKey);

// create signDatas
const signDatas = createSignDatas(ticketDatas, signatures);

// verify
verify(signDatas, signerAddress);

// output json
outputJson(
  { signerAddress: signerAddress, bitChecker: bits },
  outputDirectory,
  "settings" + name + ".json"
);
outputJson(signDatas, outputDirectory, "signDatas" + name + ".json");
