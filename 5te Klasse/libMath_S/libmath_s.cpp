#include "libmath_s.h"
#include <cmath>
#include <limits>
#define exprtk_disable_enhanced_features
#include "exprtk/exprtk.hpp"

LibMath_S::LibMath_S() {}

double LibMath_S::calculate(QString term) {
    typedef double T;
    typedef exprtk::symbol_table<T> symbol_table_t;
    typedef exprtk::expression<T>   expression_t;
    typedef exprtk::parser<T>       parser_t;

    const std::string expression_string = term.toStdString();

    symbol_table_t symbol_table;
    symbol_table.add_constants();

    expression_t expression;
    expression.register_symbol_table(symbol_table);

    parser_t parser;
    if (!parser.compile(expression_string, expression)) {
        return std::numeric_limits<double>::quiet_NaN();
    }

    return expression.value();
}