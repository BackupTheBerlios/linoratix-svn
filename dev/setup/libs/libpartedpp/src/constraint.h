#ifndef PED_CONSTRAINT_H
#define PED_CONSTRAINT_H

#include "alignment.h"
#include "geometry.h"

namespace Ped {

    class Constraint {

        friend class Disk;
        friend class FileSystem;

        private:
        Constraint( );
        Constraint(const PedConstraint *constr);
        Constraint& operator=(const Constraint &constr);

        PedConstraint           *constraint_;

        const PedConstraint*    get_c_constraint    ( ) const;

        public:
        explicit Constraint                         (Alignment& start_align,
                                                     Alignment& end_align,
                                                     Geometry& start_range,
                                                     Geometry& end_range,
                                                     Sector min_size,
                                                     Sector max_size);

        explicit Constraint                         (Geometry& min,
                                                     Geometry& max);

        explicit Constraint                         (Geometry& minmax,
                                                     bool isMin);
        explicit Constraint                         (const Constraint &constr);

        explicit Constraint                         (const Constraint &a,
                                                     const Constraint &b);

        ~Constraint                                 ( );

        Geometry&               solve_max           ( );
        Geometry&               solve_nearest       (Geometry& geom);
        bool                    is_solution         (Geometry& geom);

        protected:

    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
