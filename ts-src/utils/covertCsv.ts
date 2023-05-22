import fs from "fs";

type gasReport = {
  gasUsedForFunctions: number;
  gasUsedForSettings: number;
  totalAmounts: number;
  test: string;
  averageGasUsedForSettings: number;
  averageGasUsedForFunctions: number;
  averageGasUsedForTotal: number;
};

const inputFile = "./data/result/output.json"; // フォルダのパス
const outputFile = "./data/result/output.csv"; // 出力ファイル名

const data = fs.readFileSync(inputFile, "utf8");
const jsonData = JSON.parse(data);

const csvData = [
  Object.keys(jsonData[0]).join(","),
  ...jsonData.map((item: gasReport) => Object.values(item).join(",")),
].join("\n");

fs.writeFileSync(outputFile, csvData, "utf-8");
