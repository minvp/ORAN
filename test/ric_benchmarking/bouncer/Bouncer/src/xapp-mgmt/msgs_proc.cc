/*
# ==================================================================================
# Copyright (c) 2020 HCL Technologies Limited.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==================================================================================
*/

#include "msgs_proc.hpp"
#define BUFFER_SIZE 1024   


bool XappMsgHandler::encode_subscription_delete_request(unsigned char* buffer, size_t *buf_len){

	subscription_helper sub_helper;
	sub_helper.set_request(0); // requirement of subscription manager ... ?
	sub_helper.set_function_id(0);

	subscription_delete e2ap_sub_req_del;

	  // generate the delete request pdu

	  bool res = e2ap_sub_req_del.encode_e2ap_subscription(&buffer[0], buf_len, sub_helper);
	  if(! res){
	    mdclog_write(MDCLOG_ERR, "%s, %d: Error encoding subscription delete request pdu. Reason = %s", __FILE__, __LINE__, e2ap_sub_req_del.get_error().c_str());
	    return false;
	  }

	return true;

}

bool XappMsgHandler::decode_subscription_response(unsigned char* data_buf, size_t data_size){

	subscription_helper subhelper;
	subscription_response subresponse;
	bool res = true;
	E2AP_PDU_t *e2pdu = 0;

	asn_dec_rval_t rval;

	ASN_STRUCT_RESET(asn_DEF_E2AP_PDU, e2pdu);

	rval = asn_decode(0,ATS_ALIGNED_BASIC_PER, &asn_DEF_E2AP_PDU, (void**)&e2pdu, data_buf, data_size);
	switch(rval.code)
	{
		case RC_OK:
			   //Put in Subscription Response Object.
			   //asn_fprint(stdout, &asn_DEF_E2AP_PDU, e2pdu);
			   break;
		case RC_WMORE:
				mdclog_write(MDCLOG_ERR, "RC_WMORE");
				res = false;
				break;
		case RC_FAIL:
				mdclog_write(MDCLOG_ERR, "RC_FAIL");
				res = false;
				break;
		default:
				break;
	 }
	ASN_STRUCT_FREE(asn_DEF_E2AP_PDU, e2pdu);
	return res;

}

/*bool  XappMsgHandler::a1_policy_handler(char * message, int *message_len, a1_policy_helper &helper){

  rapidjson::Document doc;
  if (doc.Parse<kParseStopWhenDoneFlag>(message).HasParseError()){
    mdclog_write(MDCLOG_ERR, "Error: %s, %d :: Could not decode A1 JSON message %s\n", __FILE__, __LINE__, message);
    return false;
  }

  //Extract Operation
  rapidjson::Pointer temp1("/operation");
    rapidjson::Value * ref1 = temp1.Get(doc);
    if (ref1 == NULL){
      mdclog_write(MDCLOG_ERR, "Error : %s, %d:: Could not extract policy type id from %s\n", __FILE__, __LINE__, message);
      return false;
    }

   helper.operation = ref1->GetString();

  // Extract policy id type
  rapidjson::Pointer temp2("/policy_type_id");
  rapidjson::Value * ref2 = temp2.Get(doc);
  if (ref2 == NULL){
    mdclog_write(MDCLOG_ERR, "Error : %s, %d:: Could not extract policy type id from %s\n", __FILE__, __LINE__, message);
    return false;
  }
   //helper.policy_type_id = ref2->GetString();
    helper.policy_type_id = to_string(ref2->GetInt());

    // Extract policy instance id
    rapidjson::Pointer temp("/policy_instance_id");
    rapidjson::Value * ref = temp.Get(doc);
    if (ref == NULL){
      mdclog_write(MDCLOG_ERR, "Error : %s, %d:: Could not extract policy type id from %s\n", __FILE__, __LINE__, message);
      return false;
    }
    helper.policy_instance_id = ref->GetString();

    if (helper.policy_type_id == "1" && helper.operation == "CREATE"){
    	helper.status = "OK";
    	Document::AllocatorType& alloc = doc.GetAllocator();

    	Value handler_id;
    	handler_id.SetString(helper.handler_id.c_str(), helper.handler_id.length(), alloc);

    	Value status;
    	status.SetString(helper.status.c_str(), helper.status.length(), alloc);


    	doc.AddMember("handler_id", handler_id, alloc);
    	doc.AddMember("status",status, alloc);
    	doc.RemoveMember("operation");
    	StringBuffer buffer;
    	Writer<StringBuffer> writer(buffer);
    	doc.Accept(writer);
    	strncpy(message,buffer.GetString(), buffer.GetLength());
    	*message_len = buffer.GetLength();
    	return true;
    }
    return false;
}*/


//For processing received messages.XappMsgHandler should mention if resend is required or not.
void XappMsgHandler::operator()(rmr_mbuf_t *message, bool *resend)
{
/*
	if (message->len > MAX_RMR_RECV_SIZE)
	{
		mdclog_write(MDCLOG_ERR, "Error : %s, %d, RMR message larger than %d. Ignoring ...", __FILE__, __LINE__, MAX_RMR_RECV_SIZE);
		return;
	}
      		//a1_policy_helper helper;
	bool res=false;
	E2AP_PDU_t* e2pdu = (E2AP_PDU_t*)calloc(1, sizeof(E2AP_PDU));
	int num = 0;
*/	
if (message->len > MAX_RMR_RECV_SIZE){
		mdclog_write(MDCLOG_ERR, "Error : %s, %d, RMR message larger than %d. Ignoring ...", __FILE__, __LINE__, MAX_RMR_RECV_SIZE);
		return;
	}
      //a1_policy_helper helper;
	bool res =false;
	E2AP_PDU_t* e2pdu = (E2AP_PDU_t*)calloc(1, sizeof(E2AP_PDU));
	static int num = 0;
	unsigned char conreq_buf[BUFFER_SIZE];
    size_t conreq_buf_size = BUFFER_SIZE;
	static int conreqcount = 1;
	switch(message->mtype)
	{
		//need to fix the health check.
		case (RIC_HEALTH_CHECK_REQ):
			message->mtype = RIC_HEALTH_CHECK_RESP;        // if we're here we are running and all is ok
			message->sub_id = -1;
			strncpy( (char*)message->payload, "Bouncer OK\n", rmr_payload_size( message) );
			*resend = true;
			break;

		case (RIC_SUB_RESP):
        		mdclog_write(MDCLOG_INFO, "Received subscription message of type = %d", message->mtype);
			unsigned char *me_id;
			if( (me_id = (unsigned char *) malloc( sizeof( unsigned char ) * RMR_MAX_MEID )) == NULL ) 
			{
				mdclog_write(MDCLOG_ERR, "Error :  %s, %d : malloc failed for me_id", __FILE__, __LINE__);
				me_id = rmr_get_meid(message, NULL);
			} 
			else 
			{
				rmr_get_meid(message, me_id);
			}
			if(me_id == NULL)
			{
				mdclog_write(MDCLOG_ERR, " Error :: %s, %d : rmr_get_meid failed me_id is NULL", __FILE__, __LINE__);
				break;
			}
			mdclog_write(MDCLOG_INFO,"RMR Received MEID: %s",me_id);
			if(_ref_sub_handler !=NULL)
			{
				_ref_sub_handler->manage_subscription_response(message->mtype, reinterpret_cast< char const* >(me_id));
			} 
			else 
			{
				mdclog_write(MDCLOG_ERR, " Error :: %s, %d : Subscription handler not assigned in message processor !", __FILE__, __LINE__);
			}
			*resend = false;
			if (me_id != NULL) 
			{
				mdclog_write(MDCLOG_INFO, "Free RMR Received MEID memory: %s(0x%x)", me_id, me_id);
				free(me_id);
			}
			break;

		case (RIC_SUB_DEL_RESP):
        		mdclog_write(MDCLOG_INFO, "Received subscription delete message of type = %d", message->mtype);
			//unsigned char *me_id;
			if( (me_id = (unsigned char *) malloc( sizeof( unsigned char ) * RMR_MAX_MEID )) == NULL ) 
			{
				mdclog_write(MDCLOG_ERR, "Error :  %s, %d : malloc failed for me_id", __FILE__, __LINE__);
				me_id = rmr_get_meid(message, NULL);
			} 
			else 
				
			{
				rmr_get_meid(message, me_id);
			}
			if(me_id == NULL)
			{
				mdclog_write(MDCLOG_ERR, " Error :: %s, %d : rmr_get_meid failed me_id is NULL", __FILE__, __LINE__);
				break;
			}
			mdclog_write(MDCLOG_INFO,"RMR Received MEID: %s",me_id);
			if(_ref_sub_handler !=NULL)
			{
				_ref_sub_handler->manage_subscription_response(message->mtype, reinterpret_cast< char const* >(me_id));
			} 
			else 
			{
				mdclog_write(MDCLOG_ERR, " Error :: %s, %d : Subscription handler not assigned in message processor !", __FILE__, __LINE__);
			}
			*resend = false;
			if (me_id != NULL) 
			{
				mdclog_write(MDCLOG_INFO, "Free RMR Received MEID memory: %s(0x%x)", me_id, me_id);
				free(me_id);
			}
			break;
/*
		case (RIC_INDICATION):
			
			if(message->mtype == 12050)
                        {
                           	mdclog_write(MDCLOG_INFO, "Decoding indication for msg = %d", message->mtype);

                           	ASN_STRUCT_RESET(asn_DEF_E2AP_PDU, e2pdu);
                           	asn_transfer_syntax syntax;
                           	syntax = ATS_ALIGNED_BASIC_PER;

                           	mdclog_write(MDCLOG_INFO, "Data_size = %d",  message->len);

                           	auto rval =  asn_decode(nullptr, syntax, &asn_DEF_E2AP_PDU, (void**)&e2pdu, message->payload, message->len);

				if(rval.code == RC_OK)
				{
                                 	mdclog_write(MDCLOG_INFO, "rval.code = %d ", rval.code);
				}
                       		else
				{
                                 	mdclog_write(MDCLOG_ERR, " rval.code = %d ", rval.code);
                                 	break;
                        	}

                       		asn_fprint(stdout, &asn_DEF_E2AP_PDU, e2pdu);
				mdclog_write(MDCLOG_INFO, "Received indication message of type = %d", message->mtype);
   				num++;
				message->mtype = RIC_CONTROL_REQ;        // if we're here we are running and all is ok
                       		message->sub_id = -1;
                       		strncpy((char*)message->payload, "Bouncer Control OK\n", rmr_payload_size(message));
                       		*resend = true;
                       		ASN_STRUCT_FREE(asn_DEF_E2AP_PDU, e2pdu);

			 } 
			mdclog_write(MDCLOG_INFO, "Number of Indications Received = %d", num);
			 	break;

		case A1_POLICY_REQ:

		    	mdclog_write(MDCLOG_INFO, "In Message Handler: Received A1_POLICY_REQ.");
			helper.handler_id = xapp_id;

			res = a1_policy_handler((char*)message->payload, &message->len, helper);
			if(res)
			{
				message->mtype = A1_POLICY_RESP;        // if we're here we are running and all is ok
				message->sub_id = -1;
				*resend = true;
			}
			break;*/
case (RIC_INDICATION):
			/*unsigned char *meid;
			if( (me_id = (unsigned char *) malloc( sizeof( unsigned char ) * RMR_MAX_MEID )) == NULL ) {
				mdclog_write(MDCLOG_ERR, "Error :  %s, %d : malloc failed for meid", __FILE__, __LINE__);
				meid = rmr_get_meid(message, NULL);
			} else {
				rmr_get_meid(message, meid);
			}
			if(meid == NULL){
				mdclog_write(MDCLOG_ERR, " Error :: %s, %d : rmr_get_meid failed meid is NULL", __FILE__, __LINE__);
				break;
			}
			mdclog_write(MDCLOG_INFO,"RMR Received MEID: %s",meid);*/
			if(message->mtype == 12050){
                mdclog_write(MDCLOG_INFO, "Decoding indication for msg = %d", message->mtype);

                ASN_STRUCT_RESET(asn_DEF_E2AP_PDU, e2pdu);
                asn_transfer_syntax syntax;
                syntax = ATS_ALIGNED_BASIC_PER;

                mdclog_write(MDCLOG_INFO, "Data_size = %d",  message->len);

                auto rval =  asn_decode(nullptr, syntax, &asn_DEF_E2AP_PDU, (void**)&e2pdu, message->payload, message->len);

                if(rval.code == RC_OK)
                {
                     mdclog_write(MDCLOG_INFO, "rval.code = %d ", rval.code);
                }
                else{
                    	mdclog_write(MDCLOG_ERR, " rval.code = %d ", rval.code);
                        break;
                    }
				/*asn_fprint(stdout, &asn_DEF_E2AP_PDU, e2pdu);
 				mdclog_write(MDCLOG_INFO, "Received indication message of type = %d", message->mtype);
                num++;
			    message->mtype = RIC_CONTROL_REQ;        // if we're here we are running and all is ok
            	message->sub_id = -1;
                strncpy((char*)message->payload, "Bouncer Control OK\n", rmr_payload_size(message));
                *resend = true;
                ASN_STRUCT_FREE(asn_DEF_E2AP_PDU, e2pdu);*/

				num++;
				mdclog_write(MDCLOG_INFO, "Number of Indications Received = %d <file:%s>", num,__FILE__);
/* Added for CONTROL_ACKNOWLEDGEMENT - STARTED*/
                asn_fprint(stdout, &asn_DEF_E2AP_PDU, e2pdu);
			   	mdclog_write(MDCLOG_INFO, "Start sending Control request %d  <file:%s>", conreqcount,__FILE__);                        
				ric_control_helper   din;
				din.control_ack = 1;
				din.control_header = (unsigned char*)"HDR";
				din.control_header_size = strlen("HDR");
				din.control_msg = (unsigned char*)"MSG";
				din.control_msg_size = strlen("MSG");
				din.call_process_id = (unsigned char*)"CPID";
				din.call_process_id_size = strlen("CPID");

				ric_control_request  con_req;
				res = con_req.encode_e2ap_control_request(&conreq_buf[0], &conreq_buf_size, din);
 
			   	message->mtype = RIC_CONTROL_REQ;        // if we're here we are running and all is ok
                message->sub_id = -1;

				/*for(int c=0; c<5;c++)
			 		mdclog_write(MDCLOG_INFO, ".................encoded  conreq_buf[%d] = %x", c,conreq_buf[c]);*/
	
				memcpy(message->payload,(void *)(&conreq_buf[0]), conreq_buf_size);

				for(int c=0; c<5;c++)
			 		mdclog_write(MDCLOG_INFO, ".................encoded  payload[%d] = %x", c,conreq_buf[c]);

                *resend = true;
				conreqcount++;
/* Added for CONTROL_ACKNOWLEDGEMENT - ENDED*/
			 }
			 break;
		case (RIC_CONTROL_ACK):
				static int conAckCount = 1;
				mdclog_write(MDCLOG_INFO, "In RIC_CONTROL_ACK message type %d received from RMR <file:%s> ", message->mtype,__FILE__);
				mdclog_write(MDCLOG_INFO, "Number of Control Ack Count Received:  %d ", conAckCount);
				conAckCount++;
				*resend = false;
		    break;

		default:
		{
			mdclog_write(MDCLOG_ERR, "Error :: Unknown message type %d received from RMR", message->mtype);
			*resend = false;
		}
	}

	return;

};


