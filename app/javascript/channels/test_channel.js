import consumer from "./consumer"

consumer.subscriptions.create("TestChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    this.send({ message: 'Client is live' })
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    console.log(data)
  }
});
