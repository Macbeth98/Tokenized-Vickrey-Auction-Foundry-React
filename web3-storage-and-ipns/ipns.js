import { createHelia } from 'helia';
import { ipns } from '@helia/ipns';
import { dht, pubsub } from '@helia/ipns/routing';

const helia = await createHelia();

const name = ipns(helia, {
  routers: [dht(helia), pubsub(helia)],
});

const keyInfo = await helia.libp2p.keychain.createKey('kitchen-cron', 'RSA', 2048);
const peerId = await helia.libp2p.keychain.exportPeerId(keyInfo.name);

console.log(peerId);

const cid = 'bafybeibtbd3pirocevdfnmsfy2urh7njomruyu2bvkf35d5ar63uk6otem';

await name.publish(peerId, cid);

const resolved = await name.resolve(peerId);

console.log('resolved', resolved);
