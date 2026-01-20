<?php

namespace App\Mcp\Tools;

use Mcp\Capability\Attribute\McpTool;

class AddNumbers
{
    #[McpTool(
        name: 'add_numbers',
        description: 'Add two numbers together and return the result'
    )]
    public function add(
        int $number1,
        int $number2
    ): array
    {
        $result = $number1 + $number2;

        return [
            'number1' => $number1,
            'number2' => $number2,
            'result' => $result,
            'operation' => "$number1 + $number2 = $result"
        ];
    }
}
