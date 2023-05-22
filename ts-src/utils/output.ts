import * as fs from "fs";

export const output = (
  data: string,
  outputDirectory: string,
  fileName: string
) => {
  if (!fs.existsSync(outputDirectory)) {
    fs.mkdirSync(outputDirectory);
  }
  fs.writeFileSync(outputDirectory + fileName, data);
};

export const outputJson = (
  data: any[] | any,
  outputDirectory: string,
  fileName: string
) => {
  const jsonData = JSON.stringify(data, null, " ");
  if (!fs.existsSync(outputDirectory)) {
    fs.mkdirSync(outputDirectory);
  }
  fs.writeFileSync(outputDirectory + fileName, jsonData);
};

export const importJson = (filePath: string) => {
  try {
    const jsonString = fs.readFileSync(filePath, "utf-8");
    const jsonData = JSON.parse(jsonString);
    return jsonData;
  } catch (err) {
    console.error(err);
    return null;
  }
};
