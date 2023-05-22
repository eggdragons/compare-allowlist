declare global {
  type Allowlist = {
    user: string;
    allowedAmount: number;
  };

  type MerkleData = {
    user: string;
    allowedAmount: number;
    proofs: string[];
  };

  type TicketData = {
    index: number;
    user: string;
    allowedAmount: number;
  };

  type EcdsaSignData = TicketData & {
    signature: string;
  };
}

export {};
