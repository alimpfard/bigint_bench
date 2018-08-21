import scala.math.BigInt;

object Main {
  def main(args: Array[String]): Unit = {
    println((2 to 500000).foldLeft(BigInt(1))(_ * _));
  }
}
