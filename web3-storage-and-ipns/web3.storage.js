import { create } from '@web3-storage/w3up-client';
import fetch, { Blob } from 'node-fetch';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));

const client = await create();

const space = await client.createSpace('INF07500');

const myAccount = await client.login('mani.voct@gmail.com');

await myAccount.provision(space.did());

await space.save();

await client.setCurrentSpace(space.did());

function getFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = entries.flatMap((entry) => {
    const fullPath = path.resolve(dir, entry.name);
    if (entry.isDirectory()) {
      return getFiles(fullPath);
    } else {
      const content = fs.readFileSync(fullPath);
      // Use path.relative to get the relative file path based on the build directory
      const relativePath = path.relative(path.join(__dirname, 'build'), fullPath);
      // Create a new File object with the content and relative file path
      const blob = new Blob([content]); // Use Blob instead of File
      blob.name = relativePath.replace(/\\/g, '/'); // Set the file name
      return [blob];
    }
  });
  return files;
}

const buildPath = path.join(__dirname, './build');
const files = getFiles(buildPath);

console.log(files);

const directoryCid = await client.uploadDirectory(files);
console.log(directoryCid);
