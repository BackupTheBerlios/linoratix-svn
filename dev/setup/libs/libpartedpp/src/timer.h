#ifndef PED_TIMER_H
#define PED_TIMER_H

#include <parted/parted.h>
#include <string>
#include "timerhandler.h"

namespace Ped {

    class Timer {

        friend class FileSystem;
        friend class Geometry;

        private:
            PedTimer*           timer_;
            TimerHandler*       handler_;
            //struct THHelpStruct* help_struct;

            bool nested;

            PedTimer* get_c_timer() const;

        public:
            Timer(TimerHandler* handler);
            Timer(Timer* parent, float nest_frac);
            ~Timer();

            void touch();
            void reset();
            void update(float new_frac);
            void set_state_name(const std::string &state_name);

        protected:
    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
