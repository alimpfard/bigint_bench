import Data.List (foldl')

main = putStrLn $ show $ foldl' (\acc x -> acc * x) 1 ([2..500000] :: [Integer])
