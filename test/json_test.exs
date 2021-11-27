defmodule JsonTest do
  use ExUnit.Case
  doctest Json

  test "parses null" do
    assert Json.parse("null") == {:ok, nil}
  end

  test "parses true" do
    assert Json.parse("true") == {:ok, true}
  end

  test "parses false" do
    assert Json.parse("false") == {:ok, false}
  end

  test "parses 'false  '" do
    assert Json.parse("false  ") == {:ok, false}
  end

  test "parses '   false  '" do
    assert Json.parse("   false  ") == {:ok, false}
  end

  test "parses a string" do
    assert Json.parse("\"false\"") == {:ok, "false"}
  end

  test "parses a string with unicode" do
    assert Json.parse("\"\\u0041\"") == {:ok, "A"}
  end

  test "parses a escapes" do
    assert Json.parse("\"\\\"\\\\\\\n\"") == {:ok, "\"\\\n"}
  end

  test "parses a string with leading and trailing spaces" do
    assert Json.parse("   \"false\"   ") == {:ok, "false"}
  end

  test "errors on empty string" do
    assert Json.parse("") == {:err, :empty}
  end

  test "errors with value after string" do
    assert Json.parse("\"hello\" 1") == {:err, 8, "1"}
  end

  test "parses 1" do
    assert Json.parse("1") == {:ok, 1}
  end

  test "parses 123456789" do
    assert Json.parse("123456789") == {:ok, 123_456_789}
  end

  test "parses -1" do
    assert Json.parse("-1") == {:ok, -1}
  end

  test "parses 12345.6789" do
    assert Json.parse("12345.6789") == {:ok, 12345.6789}
  end

  test "errors on 12345." do
    assert Json.parse("12345.") == {:err, :unexpected_end_of_input}
  end

  test "errors on 12.34.5" do
    assert Json.parse("12.34.5") == {:err, 5, "."}
  end

  test "parses 0" do
    assert Json.parse("0") == {:ok, 0}
  end

  test "parses 10e2" do
    assert Json.parse("10e2") == {:ok, 100}
  end

  test "parses 10.1e2" do
    assert Json.parse("10.1e2") == {:ok, Float.pow(10.1, 2)}
  end

  test "errors on 10.1e2e3" do
    assert Json.parse("10.1e2e3") == {:err, 5, "e"}
  end

  test "errors on 10.1e2.3" do
    assert Json.parse("10.1e2.3") == {:err, 5, "."}
  end

  test "parses -0" do
    assert Json.parse("-0") == {:ok, -0}
  end

  test "parses -0.0" do
    assert Json.parse("-0.0") == {:ok, -0.0}
  end

  test "parses 0.1" do
    assert Json.parse("0.1") == {:ok, 0.1}
  end

  test "errors on 01" do
    assert Json.parse("01") == {:err, 1, "1"}
  end

  test "parses [ 1 , 2 , 3 , 4 , 5 ] " do
    assert Json.parse(" [ 1 , 2 , 3 , 4 , 5 ] ") == {:ok, [1, 2, 3, 4, 5]}
  end

  test "parses [[[[]]]] " do
    assert Json.parse("[[[[]]]]") == {:ok, [[[[]]]]}
  end

  test "parses '  [  ]  '" do
    assert Json.parse("  [  ]  ") == {:ok, []}
  end

  test "errors on [1,]" do
    assert Json.parse("[1,]") == {:err, 3, "]"}
  end

  test "errors on [" do
    assert Json.parse("[") == {:err, :unexpected_end_of_input}
  end

  test "parses [[[[\"hello\"]], \"world\"]] " do
    assert Json.parse("[[[[\"hello\"]], \"world\"]]") == {:ok, [[[["hello"]], "world"]]}
  end

  test "parses [[[[ \"hello\"   , \"test\"  ]], \"world\"]] " do
    assert Json.parse("[[[[ \"hello\"   , \"test\"  ]], \"world\"]]") ==
             {:ok, [[[["hello", "test"]], "world"]]}
  end

  test "parses {}" do
    assert Json.parse("{}") == {:ok, %{}}
  end

  test "errors on {" do
    assert Json.parse("{") == {:err, :unexpected_end_of_input}
  end

  test "errors on {\"key}" do
    assert Json.parse("{\"key}") == {:err, :unexpected_end_of_input}
  end

  test "parses {  \"hello\" :  \"world\"   }" do
    assert Json.parse("  {  \"hello\" :  \"world\"   }  ") == {:ok, %{"hello" => "world"}}
  end

  test "parses {\"arr\":[1,2,3]}" do
    assert Json.parse("{\"arr\":[1,2,3]}") == {:ok, %{"arr" => [1, 2, 3]}}
  end

  test "parses [{\"true\":true,\"null\":null}]" do
    assert Json.parse("[{\"true\":true,\"null\":null}]") ==
             {:ok, [%{"null" => nil, "true" => true}]}
  end

  test "real JSON parsing" do
    assert Json.parse("""
           {
           "description": "The description of the test case",
           "schema": {
               "description": "The schema against which the data in each test is validated",
               "type": "string"
           },
           "tests": [
               {
                   "description": "Test for a valid instance",
                   "data": "the instance to validate",
                   "valid": true
               },
               {
                   "description": "Test for an invalid instance",
                   "data": 15,
                   "valid": false
               }
           ]
           }
           """) ==
             {:ok,
              %{
                "description" => "The description of the test case",
                "schema" => %{
                  "description" => "The schema against which the data in each test is validated",
                  "type" => "string"
                },
                "tests" => [
                  %{
                    "data" => "the instance to validate",
                    "description" => "Test for a valid instance",
                    "valid" => true
                  },
                  %{
                    "data" => 15,
                    "description" => "Test for an invalid instance",
                    "valid" => false
                  }
                ]
              }}
  end

  test "stringifies nil" do
    assert Json.stringify(nil) == "null"
  end

  test "stringifies true" do
    assert Json.stringify(true) == "true"
  end

  test "stringifies false" do
    assert Json.stringify(false) == "false"
  end

  test "stringifies ints" do
    assert Json.stringify(123_456) == "123456"
  end

  test "stringifies floats" do
    assert Json.stringify(123.456) == "123.456"
  end

  test "stringifies lists" do
    assert Json.stringify([]) == "[]"
  end

  test "stringifies lists with elements" do
    assert Json.stringify([true, false, nil]) == "[true,false,null]"
  end

  test "stringifies maps" do
    assert Json.stringify(%{}) == "{}"
  end

  test "stringifies maps with elements" do
    assert Json.stringify(%{true => true, nil => nil}) == "{\"null\":null,\"true\":true}"
  end

  test "parses a larger json file" do
    expected =
      {:ok,
       [
         %{
           "_id" => "61a2715cd6f3a4cd2bbbf36b",
           "about" =>
             "Commodo pariatur labore dolor minim proident ea ullamco aute nulla qui ullamco. Do aliqua aliquip non ad esse velit eu et ex quis irure ipsum qui. Exercitation ipsum ad nostrud nostrud ea dolor deserunt eu eiusmod deserunt in laborum ea dolore. Culpa veniam cillum anim eiusmod elit aute anim tempor. Dolor pariatur aliquip nulla culpa reprehenderit exercitation. Amet mollit proident adipisicing aliqua. Nulla fugiat dolore enim cillum.\\r\\n",
           "address" => "668 Morton Street, Bluffview, Massachusetts, 3405",
           "age" => 31,
           "balance" => "$3,255.84",
           "company" => "ZIPAK",
           "email" => "marcihunter@zipak.com",
           "eyeColor" => "blue",
           "favoriteFruit" => "strawberry",
           "friends" => [
             %{"id" => 0, "name" => "Beryl Norris"},
             %{"id" => 1, "name" => "Gretchen Henson"},
             %{"id" => 2, "name" => "Gabriela Mcneil"}
           ],
           "gender" => "female",
           "greeting" => "Hello, Marci Hunter! You have 10 unread messages.",
           "guid" => "12845e47-a22b-471f-ba42-d65a8af4decf",
           "index" => 0,
           "isActive" => false,
           "latitude" => -9.214686,
           "longitude" => 91.713927,
           "name" => "Marci Hunter",
           "phone" => "+1 (970) 490-3930",
           "picture" => "http://placehold.it/32x32",
           "registered" => "2017-02-24T05:14:56 -01:00",
           "tags" => ["officia", "irure", "ex", "dolor", "consectetur", "est", "ea"]
         },
         %{
           "_id" => "61a2715c55d19fb7eb0f36c9",
           "about" =>
             "Excepteur consectetur est elit occaecat anim in labore do occaecat officia cillum id. Ipsum commodo et proident culpa sint fugiat. Fugiat consectetur excepteur ut elit.\\r\\n",
           "address" => "968 Pershing Loop, Riverton, Louisiana, 1482",
           "age" => 32,
           "balance" => "$3,447.36",
           "company" => "TRASOLA",
           "email" => "benjaminhorn@trasola.com",
           "eyeColor" => "brown",
           "favoriteFruit" => "banana",
           "friends" => [
             %{"id" => 0, "name" => "Audrey Barnes"},
             %{"id" => 1, "name" => "Hannah Wynn"},
             %{"id" => 2, "name" => "Esmeralda Shelton"}
           ],
           "gender" => "male",
           "greeting" => "Hello, Benjamin Horn! You have 3 unread messages.",
           "guid" => "859e2827-ecf5-4cfc-9a18-de34baf47f9e",
           "index" => 1,
           "isActive" => true,
           "latitude" => 61.033549,
           "longitude" => 25.90946,
           "name" => "Benjamin Horn",
           "phone" => "+1 (918) 497-2420",
           "picture" => "http://placehold.it/32x32",
           "registered" => "2021-07-27T11:22:30 -02:00",
           "tags" => ["consequat", "dolore", "aliqua", "labore", "sit", "consectetur", "proident"]
         },
         %{
           "_id" => "61a2715c7c62a02998d51881",
           "about" =>
             "Consectetur laborum voluptate labore incididunt ex aliqua sunt incididunt esse est ad id esse. Dolore anim deserunt nulla esse nisi ut eiusmod eu voluptate officia mollit laborum anim. Et officia eu tempor sint anim. Ea ad sunt minim in. Consectetur labore pariatur elit aliquip ullamco consectetur adipisicing est sint ad. Occaecat nisi commodo laboris sunt id ex id sit culpa culpa amet ea.\\r\\n",
           "address" => "884 Homecrest Court, Muir, Iowa, 2364",
           "age" => 23,
           "balance" => "$1,710.33",
           "company" => "DREAMIA",
           "email" => "terramcdowell@dreamia.com",
           "eyeColor" => "blue",
           "favoriteFruit" => "apple",
           "friends" => [
             %{"id" => 0, "name" => "Hooper Whitfield"},
             %{"id" => 1, "name" => "Preston Williamson"},
             %{"id" => 2, "name" => "Gwendolyn Blankenship"}
           ],
           "gender" => "female",
           "greeting" => "Hello, Terra Mcdowell! You have 3 unread messages.",
           "guid" => "0f50afcd-01af-43cf-8ef8-f0651f1446d9",
           "index" => 2,
           "isActive" => false,
           "latitude" => 17.040922,
           "longitude" => -170.673668,
           "name" => "Terra Mcdowell",
           "phone" => "+1 (874) 421-2190",
           "picture" => "http://placehold.it/32x32",
           "registered" => "2015-10-05T02:06:01 -02:00",
           "tags" => ["velit", "Lorem", "veniam", "adipisicing", "veniam", "aliqua", "veniam"]
         },
         %{
           "_id" => "61a2715c8ef22c424dd7ba47",
           "about" =>
             "Esse qui non eiusmod exercitation et id aliquip amet. Ad excepteur velit adipisicing do quis nisi commodo consequat consequat sint commodo nulla veniam. Amet labore sunt Lorem id nostrud nostrud pariatur consectetur non sit elit. Exercitation dolor mollit eu culpa aliqua laborum ea ut aliquip est laborum.\\r\\n",
           "address" => "211 Grattan Street, Marbury, Ohio, 419",
           "age" => 38,
           "balance" => "$1,690.61",
           "company" => "CALCU",
           "email" => "lelaperry@calcu.com",
           "eyeColor" => "green",
           "favoriteFruit" => "banana",
           "friends" => [
             %{"id" => 0, "name" => "Glover Boyer"},
             %{"id" => 1, "name" => "Ines Salinas"},
             %{"id" => 2, "name" => "Guy Wilkinson"}
           ],
           "gender" => "female",
           "greeting" => "Hello, Lela Perry! You have 10 unread messages.",
           "guid" => "1c659ddf-cac0-4480-a2f3-c2703ec05124",
           "index" => 3,
           "isActive" => false,
           "latitude" => 80.743705,
           "longitude" => 161.880612,
           "name" => "Lela Perry",
           "phone" => "+1 (952) 485-3741",
           "picture" => "http://placehold.it/32x32",
           "registered" => "2014-12-02T04:22:57 -01:00",
           "tags" => ["est", "ea", "enim", "cupidatat", "dolore", "exercitation", "sint"]
         },
         %{
           "_id" => "61a2715c92f26fdc030f3925",
           "about" =>
             "Anim velit culpa velit tempor tempor commodo minim ut nisi velit voluptate est ullamco laboris. Aliqua eu laborum excepteur aliquip esse sint qui proident eu incididunt. In ipsum voluptate elit nostrud occaecat. Ut amet consectetur eu nulla cupidatat ipsum minim exercitation. Lorem labore ut ut dolore tempor ipsum adipisicing amet duis eiusmod.\\r\\n",
           "address" => "196 Hemlock Street, Gorham, Hawaii, 8753",
           "age" => 22,
           "balance" => "$3,806.26",
           "company" => "ZENTURY",
           "email" => "hendrixgonzales@zentury.com",
           "eyeColor" => "green",
           "favoriteFruit" => "apple",
           "friends" => [
             %{"id" => 0, "name" => "Lori Gilmore"},
             %{"id" => 1, "name" => "Deana Hodge"},
             %{"id" => 2, "name" => "Earlene Santana"}
           ],
           "gender" => "male",
           "greeting" => "Hello, Hendrix Gonzales! You have 6 unread messages.",
           "guid" => "f6cd78c4-d2dc-4de2-910f-55f44909bd4f",
           "index" => 4,
           "isActive" => false,
           "latitude" => -15.824074,
           "longitude" => -68.681008,
           "name" => "Hendrix Gonzales",
           "phone" => "+1 (883) 456-3018",
           "picture" => "http://placehold.it/32x32",
           "registered" => "2016-12-02T04:08:05 -01:00",
           "tags" => ["mollit", "in", "esse", "ut", "proident", "irure", "sit"]
         },
         %{
           "_id" => "61a2715c174a808c185b1d2f",
           "about" =>
             "Irure esse occaecat pariatur qui elit exercitation incididunt Lorem fugiat. Exercitation eu dolore irure aute proident ipsum non laboris quis duis ea anim labore labore. In cillum incididunt occaecat consectetur id eiusmod officia consectetur. Lorem est in dolore ut duis. Consectetur laborum labore mollit eiusmod occaecat velit excepteur consequat consectetur et ipsum nisi magna irure. Quis aliqua magna eu magna. Occaecat enim esse mollit consectetur laborum cillum dolore minim.\\r\\n",
           "address" => "445 Nassau Street, Keller, Rhode Island, 7246",
           "age" => 37,
           "balance" => "$2,199.77",
           "company" => "ANACHO",
           "email" => "solomonrobinson@anacho.com",
           "eyeColor" => "green",
           "favoriteFruit" => "strawberry",
           "friends" => [
             %{"id" => 0, "name" => "Susanna Suarez"},
             %{"id" => 1, "name" => "Penelope Lee"},
             %{"id" => 2, "name" => "Bessie Cotton"}
           ],
           "gender" => "male",
           "greeting" => "Hello, Solomon Robinson! You have 4 unread messages.",
           "guid" => "63bbc612-da96-44f5-8f33-89358aa9b8e6",
           "index" => 5,
           "isActive" => false,
           "latitude" => -38.365463,
           "longitude" => 133.609495,
           "name" => "Solomon Robinson",
           "phone" => "+1 (930) 460-3155",
           "picture" => "http://placehold.it/32x32",
           "registered" => "2016-12-17T12:58:08 -01:00",
           "tags" => ["ad", "dolor", "enim", "deserunt", "incididunt", "culpa", "tempor"]
         }
       ]}

    string = File.read!("data.json")
    parsed = Json.parse(string)
    assert parsed == expected
  end
end
