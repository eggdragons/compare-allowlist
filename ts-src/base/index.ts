import { importJson, outputJson } from "../utils/output";
import { generateRandomAddress, generateRandomInt } from "../utils/random";

// import other allowlist
const importAllowlists: Allowlist[] = importJson(
  "./data/allowlist/importAllowlists.json"
);

// allowlist.length
const len = process.argv[2] ? Number(process.argv[2]) : 128;
const outputDirectory = "./data/allowlist/";

// import other allowlist && padding list --> false
const isTest = true;

// creates randomDatas
export const createAllowlists = (len: number, isTest?: boolean) => {
  const allowlists: Allowlist[] =
    isTest === true
      ? [
          {
            user: generateRandomAddress(),
            allowedAmount: isTest === true ? generateRandomInt(10) : 0,
          },
        ]
      : importAllowlists;

  // measure infinite loop
  let count = 0;
  while (allowlists.length < len && count < len + 1000) {
    const newAddress = generateRandomAddress();
    if (allowlists.some((allowlist) => allowlist.user !== newAddress)) {
      allowlists.push({
        user: newAddress,
        allowedAmount: isTest === true ? generateRandomInt(10) : 0,
      });
    }
  }
  count++;

  return allowlists;
};

const allowlists = createAllowlists(len, isTest);
// output json
outputJson(allowlists, outputDirectory, "allowlists" + len + ".json");
