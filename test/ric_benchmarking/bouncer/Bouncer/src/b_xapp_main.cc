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

#include "xapp.hpp"
#include <cpprest/http_listener.h>
#include <cpprest/json.h>
#include <cpprest/uri.h>
using namespace web;
using namespace web::http;
using namespace web::http::experimental::listener;
using namespace utility;
std::vector<std::string>SubscriptionIds;
#define TRACE(msg)            wcout << msg


void display_json(
   json::value const & jvalue)
{
        cout<<"\ndisplaying REST Notification\n";
   wcout << jvalue.serialize().c_str() << endl;
}


void handle_request(http_request request)
{
auto answer = json::value::object();
cout<<"\nPrinting POST request content\n";
cout<<request.to_string()<<"\n";
   request
      .extract_json()
      .then([&answer](pplx::task<json::value> task) {
         try
         {
            answer = task.get();
            display_json(answer);
            }
         catch (http_exception const & e)
         {
         cout<<"\ninside catch block";
            wcout << e.what() << endl;
         }

      })
      .wait();

   request.reply(status_codes::OK, answer);
}

void handle_post(http_request request)
{
   TRACE("\nhandle POST\n");

   handle_request(request);
}

void handle_put(http_request request)
{
   TRACE("\nhandle PUT\n");

   handle_request(request);
}

void start_server()
{
        
         utility::string_t port = U("8080");
         utility::string_t address = U("http://0.0.0.0:");
         address.append(port);
   	 address.append(U("/ric/v1/subscriptions/response"));
     	uri_builder uri(address);

         auto addr = uri.to_uri().to_string();
         http_listener listener(addr);
   	//http_listener listener("http://localhost:8080/ric");
   	cout<<"validated uri = "<<uri::validate(addr)<<"\n";
         ucout << utility::string_t(U("Listening for REST Notification at: ")) << addr << std::endl;
   	listener.support(methods::POST,[](http_request request) { handle_post(request);});
   	listener.support(methods::PUT,[](http_request request){  handle_put(request);});
   	try
   	{
      	listener
         	.open()
         	.then([&listener]() { })
         	.wait();

      	while (true);
   	}
   	catch (exception const & e)
   	{
      	wcout << e.what() << endl;
   	}

}

void signalHandler( int signum ) {
   cout << "Interrupt signal (" << signum << ") received.\n";
   exit(signum);
}

int main(int argc, char *argv[]){

	// Get the thread id
	std::thread::id my_id = std::this_thread::get_id();
	std::stringstream thread_id;
	std::stringstream ss;

	thread_id << my_id;

	mdclog_write(MDCLOG_INFO, "Starting thread %s",  thread_id.str().c_str());

	//get configuration
	XappSettings config;
	//change the priority depending upon application requirement
	config.loadDefaultSettings();
	config.loadEnvVarSettings();
	config.loadCmdlineSettings(argc, argv);

	//Register signal handler to stop
	signal(SIGINT, signalHandler);
	signal(SIGTERM, signalHandler);

	//getting the listening port and xapp name info
	std::string  port = config[XappSettings::SettingName::BOUNCER_PORT];
	std::string  name = config[XappSettings::SettingName::XAPP_NAME];

	//initialize rmr
	std::unique_ptr<XappRmr> rmr = std::make_unique<XappRmr>(port);
	rmr->xapp_rmr_init(true);


	//Create Subscription Handler if Xapp deals with Subscription.
	//std::unique_ptr<SubscriptionHandler> sub_handler = std::make_unique<SubscriptionHandler>();

	SubscriptionHandler sub_handler;

	//create Bouncer Xapp Instance.
	std::unique_ptr<Xapp> b_xapp;
	b_xapp = std::make_unique<Xapp>(std::ref(config),std::ref(*rmr));

	mdclog_write(MDCLOG_INFO, "Created Bouncer Xapp Instance");
	//Startup E2 subscription
	std::thread t1(std::ref(start_server));
	t1.detach();
	
	//start listener threads and register message handlers.
	int num_threads = std::stoi(config[XappSettings::SettingName::THREADS]);
	mdclog_write(MDCLOG_INFO, "Starting Listener Threads. Number of Workers = %d", num_threads);

	std::unique_ptr<XappMsgHandler> mp_handler = std::make_unique<XappMsgHandler>(config[XappSettings::SettingName::XAPP_ID], sub_handler);

	b_xapp->start_xapp_receiver(std::ref(*mp_handler));

	b_xapp->startup(sub_handler);

	sleep(10);


	/*//start listener threads and register message handlers.
	int num_threads = std::stoi(config[XappSettings::SettingName::THREADS]);
	mdclog_write(MDCLOG_INFO, "Starting Listener Threads. Number of Workers = %d", num_threads);

	std::unique_ptr<XappMsgHandler> mp_handler = std::make_unique<XappMsgHandler>(config[XappSettings::SettingName::XAPP_ID], sub_handler);

	b_xapp->start_xapp_receiver(std::ref(*mp_handler));*/

	//sleep(20);//waiting for some time before sending delete.


	//b_xapp->shutdown();//will start the sending delete procedure.
 
 	while(1){
	 			sleep(1);
	 		 }

	return 0;
}



