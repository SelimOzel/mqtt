module mqttd.server;


import mqttd.message;
import mqttd.broker;
import cerealed;
import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import std.typecons;


enum isMqttConnection(C) = isMqttSubscriber!C && is(typeof(() {
    auto c = C.init;
    c.disconnect();
}));

struct MqttServer(C) if(isMqttConnection!C) {

    this(Flag!"useCache" useCache = No.useCache) {
        _broker = MqttBroker!C(useCache);
    }

    void newMessage(R)(ref C connection, R bytes) if(isInputRangeOf!(R, ubyte)) {
        auto dec = Decerealiser(bytes);
        immutable fixedHeader = dec.value!MqttFixedHeader;
        dec.reset(); //to be used deserialising

        switch(fixedHeader.type) with(MqttType) {
            case CONNECT:
                auto code = MqttConnack.Code.ACCEPTED;
                auto connect = dec.value!MqttConnect;
                if(connect.isBadClientId) {
                    code = MqttConnack.Code.BAD_ID;
                }

                MqttConnack(code).cerealise!(b => connection.newMessage(b));
                break;

            case SUBSCRIBE:
                auto msg = dec.value!MqttSubscribe;
                _broker.subscribe(connection, msg.topics);
                const qos = msg.topics.map!(a => a.qos).array;
                MqttSuback(msg.msgId, qos).cerealise!(b => connection.newMessage(b));
                break;

            case UNSUBSCRIBE:
                auto msg = dec.value!MqttUnsubscribe;
                _broker.unsubscribe(connection, msg.topics);
                MqttUnsuback(msg.msgId).cerealise!(b => connection.newMessage(b));
                break;

            case PUBLISH:
                _broker.publish(getTopic(bytes), bytes);
                break;

            case PINGREQ:
                MqttFixedHeader(MqttType.PINGRESP).cerealise!(b => connection.newMessage(b));
                break;

            case DISCONNECT:
                _broker.unsubscribe(connection);
                connection.disconnect;
                break;

            default:
                throw new Exception(text("Don't know how to handle message of type ", fixedHeader.type));
        }
    }

    @property useCache(Flag!"useCache" useIt) {
        _broker.useCache = useIt;
    }


private:

    MqttBroker!C _broker;
}
