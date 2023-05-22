import { getAddress, hexlify, keccak256, toUtf8Bytes } from "ethers";
import crypto from "crypto";
import { privateToAddress } from "@ethereumjs/util";

export const generateRandomAddress = () => {
  return getAddress(privateToAddress(crypto.randomBytes(32)).toString("hex"));
};

export const generateRandomInt = (max: number) => {
  return Math.floor(Math.random() * (max - 1) + 1);
};

export const generatePrivateKeyFromHash = (input: string): string => {
  const hash = keccak256(toUtf8Bytes(input));
  const privateKey = hexlify(hash);

  return privateKey;
};
