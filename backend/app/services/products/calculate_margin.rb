module Products
  class CalculateMargin
    ETSY_LISTING_FEE = 0.20
    ETSY_TRANSACTION_FEE = 0.065
    ETSY_PAYMENT_PROCESSING = 0.03
    ETSY_PAYMENT_FIXED = 0.25

    def initialize(product)
      @product = product
    end

    def call
      price = @product.target_price || 0
      cost = @product.unit_cost || 0

      fees = calculate_fees(price)
      total_cost = cost + fees[:total_fees]
      profit = price - total_cost
      margin = price > 0 ? (profit / price * 100).round(1) : 0.0

      {
        sale_price: price,
        unit_cost: cost,
        fees: fees,
        total_cost: total_cost.round(2),
        profit: profit.round(2),
        margin_pct: margin,
        break_even_price: (cost + calculate_fees(cost)[:total_fees]).round(2)
      }
    end

    private

    def calculate_fees(price)
      listing_fee = ETSY_LISTING_FEE
      transaction_fee = (price * ETSY_TRANSACTION_FEE).round(2)
      payment_fee = (price * ETSY_PAYMENT_PROCESSING + ETSY_PAYMENT_FIXED).round(2)
      total = (listing_fee + transaction_fee + payment_fee).round(2)

      {
        listing_fee: listing_fee,
        transaction_fee: transaction_fee,
        payment_processing_fee: payment_fee,
        total_fees: total
      }
    end
  end
end
