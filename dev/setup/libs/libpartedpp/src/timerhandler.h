#ifndef PED_TIMERHANDLER_H
#define PED_TIMERHANDLER_H

#include <parted/parted.h>

namespace Ped {

    class TimerHandler;

    struct THHelpStruct {
        TimerHandler*   phandler;
    };

    class TimerHandler {
        private:
            PedTimerHandler*        c_handler_;
            struct THHelpStruct*    help_struct;

        public:
            TimerHandler();
            virtual ~TimerHandler();

            PedTimerHandler*        get_c_handler   ();
            THHelpStruct*           get_help_struct ();

            virtual void            invoke          () = 0;
    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
