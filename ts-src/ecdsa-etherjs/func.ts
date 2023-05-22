import { solidityPackedKeccak256, verifyMessage } from "ethers";
import { Wallet, getBytes } from "ethers";

export const createTicketDatas = (allowlists: Allowlist[]) => {
  let allowedAmount = 0;
  let index = 0;
  let bits: number[] = [];

  const ticketDatas = allowlists.map((x, i) => {
    index = index + allowedAmount;
    allowedAmount = x.allowedAmount;

    // cross the border 256n
    if (
      Math.floor(index / 256) !== Math.floor((index + allowedAmount - 1) / 256)
    ) {
      bits.push(256 - (index % 256));

      index = (Math.floor(index / 256) + 1) * 256;
    }

    // on the border 256n
    if ((index + allowedAmount) % 256 === 0) {
      bits.push(0);
    }

    // last i
    if (i === allowlists.length - 1) {
      bits.push(256 - ((index + allowedAmount) % 256));
    }

    return {
      index,
      user: x.user,
      allowedAmount,
    };
  });
  return { ticketDatas, bits };
};

export const createMessage = (ticketData: TicketData) => {
  return solidityPackedKeccak256(
    ["uint32", "address", "uint16"],
    [ticketData.index, ticketData.user, ticketData.allowedAmount]
  );
};

export const createSignature = (
  ticketDatas: TicketData[],
  privateKey: string
) => {
  const signer = new Wallet(privateKey);
  const signerAddress = signer.address;

  const signatures = ticketDatas.map((x) => {
    const message = createMessage(x);
    return signer.signMessageSync(getBytes(message));
  });

  return { signerAddress, signatures };
};

export const createSignDatas = (
  ticketDatas: TicketData[],
  signatures: string[]
) => {
  const signDatas: EcdsaSignData[] = ticketDatas.map((ticketData, i) => {
    return {
      ...ticketData,
      signature: signatures[i],
    };
  });

  return signDatas;
};

export const verify = (signDatas: EcdsaSignData[], signerAddress: string) => {
  for (let i = 0; i < signDatas.length; ++i) {
    const check =
      verifyMessage(
        getBytes(
          createMessage({
            index: signDatas[i].index,
            user: signDatas[i].user,
            allowedAmount: signDatas[i].allowedAmount,
          })
        ),
        signDatas[i].signature
      ) == signerAddress;
    if (!check) {
      throw new Error(`Verification failed for allowlist at index ${i}`);
    }
  }
};
