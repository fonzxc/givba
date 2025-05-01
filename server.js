const express = require('express');
const { Client, GatewayIntentBits } = require('discord.js');
const app = express();
app.use(express.json());

// Discord bot setup
const client = new Client({
    intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages]
});

// Replace with your bot token
const BOT_TOKEN = 'MTM2NzU4Mjk2MTQ4NjEzNTMxNg.G8Yf89.6joGG-Pg8hnJ5JXHq0ZieP2guOJeLvvBw4FsPc';
// Replace with your Discord channel ID
const CHANNEL_ID = '1367580236383785061';

client.once('ready', () => {
    console.log(`Logged in as ${client.user.tag}`);
});

client.login(BOT_TOKEN);

// HTTP endpoint for Roblox to send logs
app.post('/log', async (req, res) => {
    try {
        const channel = await client.channels.fetch(CHANNEL_ID);
        if (channel) {
            await channel.send(req.body.content);
            res.status(200).send('Log sent');
        } else {
            res.status(404).send('Channel not found');
        }
    } catch (error) {
        console.error('Error sending log:', error);
        res.status(500).send('Error sending log');
    }
});

// Start the server
app.listen(3000, () => {
    console.log('Server running on port 3000');
});
