import pyshark
from robot.api.deco import keyword

@keyword
def remote_capture_e2ap(peerip=None, peerinterface=None, timeout=None):
    capture = pyshark.RemoteCapture(remote_host=peerip, remote_interface=peerinterface, decode_as={'sctp.port==36422': 'e2ap'})
    capture.set_debug()
    capture.sniff(timeout=int(timeout))
    return capture

def remote_capture_http(peerip=None, peerinterface=None, timeout=None):
    capture = pyshark.RemoteCapture(remote_host=peerip, remote_interface=peerinterface, decode_as={'tcp.port==3800': 'http'})
    capture.set_debug()
    capture.sniff(timeout=int(timeout))
    return capture

def remote_capture_http_test(peerip=None, peerinterface=None, port=None, timeout=None):
    capture = pyshark.RemoteCapture(remote_host=peerip, remote_interface=peerinterface, remote_port=port, decode_as={'tcp.port==3800': 'http'})
    capture.set_debug()
    capture.sniff(timeout=int(timeout))
    return capture

def write_packets_to_list(capture):
    output = []
    for i in range(len(capture)):
        c = str(capture[i])
        output.append(c)
    return output
