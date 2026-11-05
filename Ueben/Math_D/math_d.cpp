#include "math_d.h"
#include <QString>

#define exprtk_disable_enhanced_features

#include "../Calculator/exprtk/exprtk.hpp"

Math_D::Math_D() {}

float Math_D::calculate(QString text) {
    typedef double T;
    typedef exprtk::symbol_table<T> symbol_table_t;
    typedef exprtk::expression<T>   expression_t;
    typedef exprtk::parser<T>       parser_t;

    const std::string expression_string = (text).toStdString();

    T x = T(1);
    T y = T(2);

    symbol_table_t symbol_table;
    symbol_table.add_variable("x",x);
    symbol_table.add_variable("y",y);
    symbol_table.add_constants();

    expression_t expression;
    expression.register_symbol_table(symbol_table);

    parser_t parser;
    parser.compile(expression_string,expression);

    T result = expression.value();
    return result;
}
