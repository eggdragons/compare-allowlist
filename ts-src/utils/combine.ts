import fs from "fs";
import path from "path";

const folderPath = "./data/result"; // フォルダのパス
const outputFile = "./data/result/output.json"; // 出力ファイル名

// フォルダ内のファイル一覧を取得
const files = fs.readdirSync(folderPath);

// データの結合用の配列
const combinedData: any[] = [];

// ファイルごとにデータを読み込んで結合
files.forEach((file) => {
  if (file !== "output.json") {
    const filePath = path.join(folderPath, file);
    const data = fs.readFileSync(filePath, "utf8");
    const jsonData = JSON.parse(data);

    // ファイル名を取得してデータに追加
    const fileName = path.basename(file, ".json");
    const averageGasUsedForSettings = Math.floor(
      jsonData.gasUsedForSettings / jsonData.totalAmounts
    );
    const averageGasUsedForFunctions = Math.floor(
      jsonData.gasUsedForFunctions / jsonData.totalAmounts
    );

    const averageGasUsedForTotal =
      averageGasUsedForSettings + averageGasUsedForFunctions;

    jsonData["test"] = fileName;
    jsonData["averageGasUsedForSettings"] = averageGasUsedForSettings;
    jsonData["averageGasUsedForFunctions"] = averageGasUsedForFunctions;
    jsonData["averageGasUsedForTotal"] = averageGasUsedForTotal;

    combinedData.push(jsonData);
  }
});

// 結合したデータを出力ファイルに書き込む
const outputData = JSON.stringify(combinedData, null, 2);
fs.writeFileSync(outputFile, outputData, "utf8");
