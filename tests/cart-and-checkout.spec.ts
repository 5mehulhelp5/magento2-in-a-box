import { test, expect } from "@playwright/test";

test.describe("Cart and checkout (sample data)", () => {
  test("add a product to the cart", async ({ page }) => {
    // Navigate to a known sample data product
    await page.goto("/joust-duffle-bag.html");

    await expect(
      page.getByRole("heading", { name: /joust duffle bag/i })
    ).toBeVisible({ timeout: 30_000 });

    await page.getByRole("button", { name: /add to cart/i }).click();

    // Wait for the success message
    await expect(
      page.getByText(/you added .* to your shopping cart/i)
    ).toBeVisible({ timeout: 30_000 });

    // Verify the cart counter shows at least 1 item
    await expect(page.locator(".counter-number")).toHaveText(/[1-9]/);
  });

  test("checkout page loads", async ({ page }) => {
    // Add a product first so we can reach the checkout
    await page.goto("/joust-duffle-bag.html");
    await expect(page.getByRole("button", { name: /add to cart/i })).toBeVisible({ timeout: 30_000 });
    await page.getByRole("button", { name: /add to cart/i }).click();
    await expect(
      page.getByText(/you added .* to your shopping cart/i)
    ).toBeVisible({ timeout: 30_000 });

    // Navigate to checkout
    await page.goto("/checkout/");

    // The checkout page should show the shipping step
    await expect(
      page.getByText(/shipping address/i)
    ).toBeVisible({ timeout: 30_000 });
  });
});
