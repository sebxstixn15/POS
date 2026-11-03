#ifndef MATH_D_GLOBAL_H
#define MATH_D_GLOBAL_H

#include <QtCore/qglobal.h>

#if defined(MATH_D_LIBRARY)
#define MATH_D_EXPORT Q_DECL_EXPORT
#else
#define MATH_D_EXPORT Q_DECL_IMPORT
#endif

#endif // MATH_D_GLOBAL_H
