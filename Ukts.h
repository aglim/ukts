#ifndef UKTS_H
#define UKTS_H

typedef nx_struct rf_msg
{
	nx_uint16_t    id;
	nx_uint16_t    reply_id;
	nx_uint32_t    t;
	nx_uint32_t    x;
	nx_uint32_t    y;
	// debug
	nx_uint32_t    t_received;
} rf_msg_t;

typedef nx_struct req_msg
{
	nx_uint16_t    id;
	nx_uint32_t    x;
	nx_uint32_t    y;
	nx_uint32_t    t;
} req_msg_t;

/*
broadcast neighbors' info
*/
typedef nx_struct neighbor_msg
{
	nx_uint16_t id;
	nx_uint8_t state;
	nx_uint32_t unadjVal;
	nx_uint32_t adjVal;
	nx_uint32_t delta;
	nx_uint32_t timestamp;
} neighbor_msg_t;

enum
{
	AM_RF_MSG = 155,
	AM_REQ_MSG = 100,
	AM_NEIGHBOR_MSG = 110,
};

#endif
