## Video Call Flutter App 📱

### Description:
- This is sandbox video call application using Flutter and WebRTC, you can call from browser to browser, phone to phone, browser to phone and opposite.

### How does it work?
<img src="https://reviewkhachsan.com/wp-content/uploads/2021/04/What-is-WebRTC-and-How-to-Disable-it-in-Your-Browser-shutterstock-body.jpg" height="350px" width="600px" />

- 🚀 **Client 1** and **Client 2** create peer connection by request create to **Server STUN** (url stun server: stun:stun.l.google.com:19302)
<img src="https://bloggeek.me/wp-content/uploads/2017/11/201711-NAT-example.jpg">

- **Client 1** request **Server STUN** create offer
- **Server STUN** will response sdp text and type is "offer" to **Client 1**
- **Client 1** need copy sdp text, type and send to **Client 2** then ** Client 2** set peer connection remote to sdp of **Client 1** 
- **Client 2** create answer for **Client 1**
- **Server STUN** will response sdp text,type(is "answer") and candidate string to **Client 2**
- **Client 2** need copy above responses and send to **Client 1**
- **Client 1** set peer connection remote to sdp of **Client 2** and add candidate of **Client 2**
- 🚀 Okay, Client 1 and 2 connected...

### Multiple peers possible?

- I found 3 ways for do it!

#### 🚀 **Option 1**: Mesh Model
<img src="https://lh5.googleusercontent.com/dZz8iCifelmoStbR2wstm5cUMyh5IM1XnIan9t7num6YflZ3_AvI89PByJJGv6Sehi86B5RdOOHI0uhfVBcV1WIp1-ihhHJkl5dKjDSzpSxCvCoU84rzV5q1-b6DL2djQdL003J7" width="600px"/>

- It looks similar to WebRTC basic P2P, with this model if there are 6 or more users the performance will be very bad.

#### 🚀 **Option 2**: MCUs – Multipoint Control Units
<img src="https://lh3.googleusercontent.com/01AEN-RDO0IVtK12jTyShrDgMABwXXumCJeCCmaXlsyLL9i2XXNKZ2Kz3BEoWeJzi2GUkSVtosLnVkFDAEVA1SeSHFUmFb8lMdNta8rKlJhSpB__5uyblm5wMrNjXUWYni-GMPCU" width="600px"/>

- MCUs are also referred to as Multipoint Conferencing Units. Whichever way you spell it out, the basic functionality is shown in the following diagram.
- Each peer in the group call establishes a connection with the MCU server to send up its video and audio. The MCU, in turn, makes a composite video and audio stream containing all of the video/audio from each of the peers, and sends that back to everyone.
- Regardless of the number of participants in the call, the MCU makes sure that each participant gets only one set of video and audio. This means the participants’ computers don’t have to do nearly as much work. The tradeoff is that the MCU is now doing that same work. So, as your calls and applications grow, you will need bigger servers in an MCU-based architecture than an SFU-based architecture. But, your participants can access the streams reliably and you won’t bog down their devices.
- Media servers that implement MCU architectures include Kurento (which Twilio Video is based on), Frozen Mountain, and FreeSwitch.

#### 🚀 **Option 3**: SFUs – Selective Forwarding Units
<img src="https://lh4.googleusercontent.com/puUKv2ve5bkx88wUhb_OG7ydimoSi74_hXT1akU7YUzmrSg29arhlhwWdg5e6x03KhBwnt_7OD0qVOYNfq-U3tpjVgDAwGMkzklVuUWp-jcNXUzPXFWJgD9oowQHWSVu5NxZtwB4" width="600px"/>

- In this case, each participant still sends just one set of video and audio up to the SFU, like our MCU. However, the SFU doesn’t make any composite streams. Rather, it sends a different stream down for each user. In this example, 4 streams are received by each participant, since there are 5 people in the call.
- The good thing about this is it’s still less work on each participant than a mesh peer-to-peer model. This is because each participant is only establishing one connection (to the SFU) instead of to all other participants to upload their own video/audio. But, it can be more bandwidth intensive than the MCU because the participants each receive multiple streams downloaded.
- The nice thing for participants about receiving separate streams is that they can do whatever they want with them. They are not bound to layout or UI decisions of the MCU. If you have been in a conference call where the conferencing tool allowed you to choose a different layout (ie, which speaker’s video will be most prominent, or how you want to arrange the videos on the screen), then that was using an SFU.
- Media servers which implement an SFU architecture include Jitsi and Janus.

#### Reference link: https://webrtc.ventures/2020/12/webrtc-media-servers-sfus-vs-mcus/
