import amqp from "amqplib";

let channel: amqp.Channel;

const MAX_RETRIES = 10;
const RETRY_DELAY_MS = 3000;

export const connectRabbitMQ = async () => {
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const connection = await amqp.connect(process.env.RABBITMQ_URL!);
      channel = await connection.createChannel();

      await channel.assertQueue(process.env.PAYMENT_QUEUE!, { durable: true });
      await channel.assertQueue(process.env.RIDER_QUEUE!, { durable: true });

      console.log("connected To Rabbitmq(restaurant service)");
      return;
    } catch (err) {
      console.warn(
        `[RabbitMQ] Attempt ${attempt}/${MAX_RETRIES} failed. Retrying in ${RETRY_DELAY_MS}ms...`,
      );
      if (attempt === MAX_RETRIES) throw err;
      await new Promise((res) => setTimeout(res, RETRY_DELAY_MS));
    }
  }
};

export const getChannel = () => channel;
