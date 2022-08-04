import pyshark
from robot.api.deco import keyword
from custom_remote_capture import CustomRemoteCapture

@keyword
def remote_capture(peerip=None, peerinterface=None, timeout=None):
    capture = pyshark.RemoteCapture(remote_host=peerip, remote_interface=peerinterface, decode_as={'sctp.port==36422': 'e2ap'})
    capture.set_debug()
    capture.sniff(timeout=int(timeout))
    return capture

def write_packets_to_list(capture):
    output = []
    for i in range(len(capture)):
        c = str(capture[i])
        output.append(c)
    return output

def custom_remote_capture(peerip=None, peerinterface=None, timeout=None, outputfile=None):
    capture = CustomRemoteCapture(remote_host=peerip, remote_interface=peerinterface, output_file=outputfile)
    capture.set_debug()
    capture.sniff(timeout=int(timeout))
    return capture

def decode_as_e2ap(outputfile):
    decode = pyshark.FileCapture(input_file=outputfile)
    output = []
    for i in decode:
        output.append(str(i))
    return output

